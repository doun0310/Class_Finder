import { UnauthorizedException, ValidationPipe } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as request from 'supertest';

import { AppModule } from '../src/app.module';
import { SocialTokenVerifier } from '../src/auth/social-token-verifier.service';
import { PrismaService } from '../src/prisma/prisma.service';
import { InMemoryPrismaService } from './support/in-memory-prisma';

describe('Auth and timetable API (e2e)', () => {
  let moduleRef: TestingModule;
  let prisma: InMemoryPrismaService;
  let app: INestApplication;

  beforeEach(async () => {
    prisma = new InMemoryPrismaService();
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(prisma)
      .overrideProvider(SocialTokenVerifier)
      .useValue(new FakeSocialTokenVerifier())
      .compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('signs up, restores the session, updates the profile, and revokes the token on signout', async () => {
    const signUp = await request(app.getHttpServer())
      .post('/auth/signup')
      .send({
        email: 'student@example.com',
        password: 'password123',
        name: 'Student Kim',
        studentId: '20230001',
        department: 'Computer Science',
        grade: 2,
      })
      .expect(201);

    expect(signUp.body.user.email).toBe('student@example.com');
    expect(signUp.body.token).toEqual(expect.any(String));

    const token = signUp.body.token as string;

    await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body.user.name).toBe('Student Kim');
        expect(body.user.department).toBe('Computer Science');
      });

    await request(app.getHttpServer())
      .patch('/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: 'Updated Kim',
        grade: 3,
      })
      .expect(200)
      .expect(({ body }) => {
        expect(body.user.name).toBe('Updated Kim');
        expect(body.user.grade).toBe(3);
      });

    await request(app.getHttpServer())
      .post('/auth/signout')
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect({ ok: true });

    await request(app.getHttpServer())
      .get('/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(401);

    await request(app.getHttpServer())
      .post('/auth/signin')
      .send({
        email: 'student@example.com',
        password: 'password123',
      })
      .expect(200)
      .expect(({ body }) => {
        expect(body.user.email).toBe('student@example.com');
      });
  });

  it('locks sign in after repeated wrong passwords', async () => {
    await request(app.getHttpServer()).post('/auth/signup').send({
      email: 'student@example.com',
      password: 'password123',
      name: 'Student Kim',
      studentId: '20230001',
      department: 'Computer Science',
      grade: 2,
    });

    for (let attempt = 0; attempt < 4; attempt += 1) {
      await request(app.getHttpServer())
        .post('/auth/signin')
        .send({
          email: 'student@example.com',
          password: 'wrong-password',
        })
        .expect(401);
    }

    await request(app.getHttpServer())
      .post('/auth/signin')
      .send({
        email: 'student@example.com',
        password: 'wrong-password',
      })
      .expect(429);

    await request(app.getHttpServer())
      .post('/auth/signin')
      .send({
        email: 'student@example.com',
        password: 'password123',
      })
      .expect(429);
  });

  it('uses only verified provider identity for social sign-in', async () => {
    const first = await request(app.getHttpServer())
      .post('/auth/social-signin')
      .send({
        provider: 'google',
        idToken: 'verified-token',
        email: 'spoofed@example.com',
        displayName: 'Spoofed User',
        providerUserId: 'spoofed-id',
      })
      .expect(200);

    expect(first.body.user.email).toBe('verified.google@example.com');
    expect(first.body.user.name).toBe('Verified google');
    expect(first.body.user.department).toBe('');
    expect(first.body.user.grade).toBe(1);
    expect(first.body.user.profileComplete).toBe(false);
    expect(first.body.user.id).toEqual(expect.any(String));

    const second = await request(app.getHttpServer())
      .post('/auth/social-signin')
      .send({
        provider: 'google',
        idToken: 'verified-token',
        email: 'different-spoof@example.com',
        displayName: 'Another Spoof',
        providerUserId: 'another-spoof-id',
      })
      .expect(200);

    expect(second.body.user.id).toBe(first.body.user.id);
    expect(second.body.user.email).toBe('verified.google@example.com');
  });

  it('rejects social sign-in when the provider token is missing', async () => {
    await request(app.getHttpServer())
      .post('/auth/social-signin')
      .send({
        provider: 'google',
        email: 'spoofed@example.com',
      })
      .expect(401);
  });

  it('redirects Apple web callback back to the Android app', async () => {
    const response = await request(app.getHttpServer())
      .post('/auth/apple/callback')
      .type('form')
      .send({
        code: 'apple-code',
        id_token: 'apple-id-token',
        state: 'apple-state',
      })
      .expect(302);

    expect(response.headers.location).toContain('intent://callback?');
    expect(response.headers.location).toContain('code=apple-code');
    expect(response.headers.location).toContain('id_token=apple-id-token');
    expect(response.headers.location).toContain(
      'package=com.maiyard.class_finder',
    );
    expect(response.headers.location).toContain('scheme=signinwithapple');
  });

  it('blocks access to another user timetable collection', async () => {
    const owner = await request(app.getHttpServer()).post('/auth/signup').send({
      email: 'owner@example.com',
      password: 'password123',
      name: 'Owner',
      studentId: '20230002',
      department: 'Computer Science',
      grade: 2,
    });
    const viewer = await request(app.getHttpServer())
      .post('/auth/signup')
      .send({
        email: 'viewer@example.com',
        password: 'password123',
        name: 'Viewer',
        studentId: '20230003',
        department: 'Computer Science',
        grade: 3,
      });

    await request(app.getHttpServer())
      .get(`/users/${owner.body.user.id}/timetables`)
      .set('Authorization', `Bearer ${viewer.body.token}`)
      .expect(401)
      .expect(({ body }) => {
        expect(body.message).toBe('You can only access your own timetables.');
      });
  });

  it('creates, lists, renames, and deletes a timetable for the signed-in user', async () => {
    const signUp = await request(app.getHttpServer()).post('/auth/signup').send({
      email: 'planner@example.com',
      password: 'password123',
      name: 'Planner',
      studentId: '20230004',
      department: 'Computer Science',
      grade: 2,
    });
    const userId = signUp.body.user.id as string;
    const token = signUp.body.token as string;

    await request(app.getHttpServer())
      .get(`/users/${userId}/timetables`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect({ timetables: [] });

    const create = await request(app.getHttpServer())
      .post(`/users/${userId}/timetables`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        name: '  Plan A  ',
        score: 84.5,
        scoreBreakdown: {
          credits: 1,
          spacing: 0.8,
        },
        courses: [
          {
            id: 'CSE201-001',
            name: 'Data Structures',
            professor: 'Prof. Lee',
            credit: 3,
            rating: 4.2,
            difficulty: 3,
            hasTeamProject: false,
            isMajorRequired: true,
            category: 'majorRequired',
            ratingSource: 'officialEstimate',
            grade: 2,
            timeSlots: [
              { day: 'Mon', startHour: 9, endHour: 11 },
              { day: 'Wed', startHour: 9, endHour: 11 },
            ],
          },
          {
            id: 'BAL101-001',
            name: 'Balanced Liberal Arts',
            professor: 'Prof. Park',
            credit: 2,
            rating: 3.8,
            difficulty: 2,
            hasTeamProject: false,
            isMajorRequired: false,
            category: 'balancedLiberalArts',
            ratingSource: 'officialEstimate',
            grade: 0,
            timeSlots: [{ day: 'Fri', startHour: 14, endHour: 16 }],
          },
        ],
      })
      .expect(201);

    const timetableId = create.body.timetable.id as string;
    expect(create.body.timetable.name).toBe('Plan A');
    expect(create.body.timetable.score).toBe(84.5);
    expect(create.body.timetable.courses).toHaveLength(2);
    expect(create.body.timetable.courses[0].timeSlots).toHaveLength(2);
    expect(create.body.timetable.courses[0].category).toBe('majorRequired');
    expect(create.body.timetable.courses[1].category).toBe(
      'balancedLiberalArts',
    );

    await request(app.getHttpServer())
      .get(`/users/${userId}/timetables`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect(({ body }) => {
        expect(body.timetables).toHaveLength(1);
        expect(body.timetables[0].id).toBe(timetableId);
        expect(body.timetables[0].scoreBreakdown.spacing).toBe(0.8);
      });

    await request(app.getHttpServer())
      .patch(`/users/${userId}/timetables/${timetableId}`)
      .set('Authorization', `Bearer ${token}`)
      .send({ name: '   ' })
      .expect(200)
      .expect(({ body }) => {
        expect(body.timetable.name).toBe('Saved Timetable');
      });

    await request(app.getHttpServer())
      .delete(`/users/${userId}/timetables/${timetableId}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect({ ok: true });

    await request(app.getHttpServer())
      .get(`/users/${userId}/timetables`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200)
      .expect({ timetables: [] });
  });
});

class FakeSocialTokenVerifier {
  async verify(input: {
    provider: 'google' | 'kakao' | 'apple';
    idToken?: string;
    accessToken?: string;
  }) {
    if (!input.idToken && !input.accessToken) {
      throw new UnauthorizedException('Provider token is required.');
    }

    return {
      provider: input.provider,
      providerUserId: `${input.provider}-verified-user`,
      email: `verified.${input.provider}@example.com`,
      displayName: `Verified ${input.provider}`,
    };
  }
}
