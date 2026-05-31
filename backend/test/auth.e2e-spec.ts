import { ValidationPipe } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as request from 'supertest';

import { AppModule } from '../src/app.module';
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
        ],
      })
      .expect(201);

    const timetableId = create.body.timetable.id as string;
    expect(create.body.timetable.name).toBe('Plan A');
    expect(create.body.timetable.score).toBe(84.5);
    expect(create.body.timetable.courses).toHaveLength(1);
    expect(create.body.timetable.courses[0].timeSlots).toHaveLength(2);
    expect(create.body.timetable.courses[0].category).toBe('majorRequired');

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
