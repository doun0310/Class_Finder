import { randomUUID } from 'node:crypto';

type StoredUser = {
  id: string;
  email: string | null;
  name: string | null;
  studentId: string | null;
  department: string | null;
  grade: number | null;
  createdAt: Date;
  passwordHash: string | null;
  passwordSalt: string | null;
  failedLoginCount: number;
  lockedUntil: Date | null;
  socialProvider: string | null;
  providerUserId: string | null;
};

type StoredSession = {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  revokedAt: Date | null;
};

type StoredSlot = {
  id: string;
  day: string;
  startHour: number;
  endHour: number;
  position: number;
};

type StoredCourse = {
  id: string;
  externalId: string;
  courseCode: string;
  section: string;
  name: string;
  professor: string;
  credit: number;
  rating: number;
  difficulty: number;
  hasTeamProject: boolean;
  isMajorRequired: boolean;
  category: string;
  ratingSource: string;
  grade: number;
  position: number;
  timeSlots: StoredSlot[];
};

type StoredTimetable = {
  id: string;
  userId: string;
  name: string;
  score: number;
  scoreBreakdown: Record<string, number>;
  savedAt: Date;
  createdAt: Date;
  updatedAt: Date;
  courses: StoredCourse[];
};

type TimetableCreateInput = {
  userId: string;
  name: string;
  score: number;
  scoreBreakdown: Record<string, number>;
  courses: {
    create: Array<{
      externalId: string;
      courseCode: string;
      section: string;
      name: string;
      professor: string;
      credit: number;
      rating: number;
      difficulty: number;
      hasTeamProject: boolean;
      isMajorRequired: boolean;
      category: string;
      ratingSource: string;
      grade: number;
      position: number;
      timeSlots: {
        create: Array<{
          day: string;
          startHour: number;
          endHour: number;
          position: number;
        }>;
      };
    }>;
  };
};

export class InMemoryPrismaService {
  private readonly users = new Map<string, StoredUser>();
  private readonly sessions = new Map<string, StoredSession>();
  private readonly timetables = new Map<string, StoredTimetable>();

  readonly user = {
    findUnique: async ({ where }: { where: { id?: string; email?: string } }) =>
      this.findUser(where),
    findFirst: async ({
      where,
    }: {
      where: { OR?: Array<Record<string, unknown>> };
    }) => this.findFirstUser(where.OR ?? []),
    create: async ({ data }: { data: Partial<StoredUser> }) =>
      this.cloneUser(this.createUser(data)),
    update: async ({
      where,
      data,
    }: {
      where: { id: string };
      data: Partial<StoredUser>;
    }) => {
      const user = this.users.get(where.id);
      if (!user) {
        throw new Error(`User ${where.id} not found.`);
      }
      Object.assign(user, this.clean(data));
      return this.cloneUser(user);
    },
    upsert: async ({
      where,
      update,
      create,
    }: {
      where: { id: string };
      update: Partial<StoredUser>;
      create: Partial<StoredUser>;
    }) => {
      const existing = this.users.get(where.id);
      if (existing) {
        Object.assign(existing, this.clean(update));
        return this.cloneUser(existing);
      }
      return this.cloneUser(this.createUser({ id: where.id, ...create }));
    },
  };

  readonly authSession = {
    create: async ({
      data,
    }: {
      data: Omit<StoredSession, 'id' | 'revokedAt'>;
    }) => {
      const session: StoredSession = {
        id: randomUUID(),
        revokedAt: null,
        ...data,
      };
      this.sessions.set(session.id, session);
      return { ...session };
    },
    findFirst: async ({
      where,
      include,
    }: {
      where: {
        tokenHash?: string;
        revokedAt?: null;
        expiresAt?: { gt: Date };
      };
      include?: { user?: boolean };
    }) => {
      for (const session of this.sessions.values()) {
        if (where.tokenHash && session.tokenHash !== where.tokenHash) {
          continue;
        }
        if (where.revokedAt === null && session.revokedAt !== null) {
          continue;
        }
        if (
          where.expiresAt?.gt &&
          session.expiresAt.getTime() <= where.expiresAt.gt.getTime()
        ) {
          continue;
        }

        if (include?.user) {
          const user = this.users.get(session.userId);
          if (!user) {
            continue;
          }
          return { ...session, user: this.cloneUser(user) };
        }

        return { ...session };
      }

      return null;
    },
    updateMany: async ({
      where,
      data,
    }: {
      where: { tokenHash?: string; revokedAt?: null };
      data: Partial<StoredSession>;
    }) => {
      let count = 0;
      for (const session of this.sessions.values()) {
        if (where.tokenHash && session.tokenHash !== where.tokenHash) {
          continue;
        }
        if (where.revokedAt === null && session.revokedAt !== null) {
          continue;
        }
        Object.assign(session, this.clean(data));
        count += 1;
      }
      return { count };
    },
    deleteMany: async ({
      where,
    }: {
      where: {
        userId?: string;
        OR?: Array<{
          expiresAt?: { lte: Date };
          revokedAt?: { not: null };
        }>;
      };
    }) => {
      let count = 0;
      for (const [id, session] of this.sessions.entries()) {
        if (where.userId && session.userId !== where.userId) {
          continue;
        }
        const matchesOr =
          !where.OR ||
          where.OR.some((condition) => {
            if (
              condition.expiresAt?.lte &&
              session.expiresAt.getTime() <= condition.expiresAt.lte.getTime()
            ) {
              return true;
            }
            if (condition.revokedAt?.not === null && session.revokedAt !== null) {
              return true;
            }
            return false;
          });
        if (!matchesOr) {
          continue;
        }

        this.sessions.delete(id);
        count += 1;
      }
      return { count };
    },
  };

  readonly savedTimetable = {
    findMany: async ({
      where,
    }: {
      where: { userId: string };
      orderBy?: Array<Record<string, string>>;
      include?: unknown;
    }) =>
      [...this.timetables.values()]
        .filter((timetable) => timetable.userId === where.userId)
        .sort((left, right) => {
          const savedAtDiff =
            right.savedAt.getTime() - left.savedAt.getTime();
          if (savedAtDiff != 0) {
            return savedAtDiff;
          }
          return right.createdAt.getTime() - left.createdAt.getTime();
        })
        .map((timetable) => this.cloneTimetable(timetable)),
    create: async ({
      data,
    }: {
      data: TimetableCreateInput;
      include?: unknown;
    }) => {
      const now = new Date();
      const timetable: StoredTimetable = {
        id: randomUUID(),
        userId: data.userId,
        name: data.name,
        score: data.score,
        scoreBreakdown: { ...data.scoreBreakdown },
        savedAt: now,
        createdAt: now,
        updatedAt: now,
        courses: data.courses.create
            .map((course) => ({
              id: randomUUID(),
              externalId: course.externalId,
              courseCode: course.courseCode,
              section: course.section,
              name: course.name,
              professor: course.professor,
              credit: course.credit,
              rating: course.rating,
              difficulty: course.difficulty,
              hasTeamProject: course.hasTeamProject,
              isMajorRequired: course.isMajorRequired,
              category: course.category,
              ratingSource: course.ratingSource,
              grade: course.grade,
              position: course.position,
              timeSlots: course.timeSlots.create
                  .map((slot) => ({
                    id: randomUUID(),
                    day: slot.day,
                    startHour: slot.startHour,
                    endHour: slot.endHour,
                    position: slot.position,
                  }))
                  .sort((left, right) => left.position - right.position),
            }))
            .sort((left, right) => left.position - right.position),
      };
      this.timetables.set(timetable.id, timetable);
      return this.cloneTimetable(timetable);
    },
    updateMany: async ({
      where,
      data,
    }: {
      where: { id: string; userId: string };
      data: { name?: string };
    }) => {
      const timetable = this.timetables.get(where.id);
      if (!timetable || timetable.userId !== where.userId) {
        return { count: 0 };
      }

      if (data.name !== undefined) {
        timetable.name = data.name;
        timetable.updatedAt = new Date();
      }

      return { count: 1 };
    },
    findUnique: async ({
      where,
    }: {
      where: { id: string };
      include?: unknown;
    }) => {
      const timetable = this.timetables.get(where.id);
      return timetable ? this.cloneTimetable(timetable) : null;
    },
    deleteMany: async ({
      where,
    }: {
      where: { id: string; userId: string };
    }) => {
      const timetable = this.timetables.get(where.id);
      if (!timetable || timetable.userId !== where.userId) {
        return { count: 0 };
      }

      this.timetables.delete(where.id);
      return { count: 1 };
    },
  };

  private findUser(where: { id?: string; email?: string }) {
    if (where.id) {
      const user = this.users.get(where.id);
      return user ? this.cloneUser(user) : null;
    }

    if (where.email) {
      for (const user of this.users.values()) {
        if (user.email === where.email) {
          return this.cloneUser(user);
        }
      }
    }

    return null;
  }

  private findFirstUser(conditions: Array<Record<string, unknown>>) {
    for (const user of this.users.values()) {
      for (const condition of conditions) {
        if (condition.email && user.email === condition.email) {
          return this.cloneUser(user);
        }
        if (
          condition.socialProvider === user.socialProvider &&
          condition.providerUserId === user.providerUserId
        ) {
          return this.cloneUser(user);
        }
      }
    }

    return null;
  }

  private createUser(data: Partial<StoredUser>) {
    const user: StoredUser = {
      id: data.id ?? randomUUID(),
      email: data.email ?? '',
      name: data.name ?? '',
      studentId: data.studentId === undefined ? '' : data.studentId,
      department: data.department === undefined ? '' : data.department,
      grade: data.grade === undefined ? 1 : data.grade,
      createdAt: data.createdAt ?? new Date(),
      passwordHash: data.passwordHash ?? null,
      passwordSalt: data.passwordSalt ?? null,
      failedLoginCount: data.failedLoginCount ?? 0,
      lockedUntil: data.lockedUntil ?? null,
      socialProvider: data.socialProvider ?? null,
      providerUserId: data.providerUserId ?? null,
    };
    this.users.set(user.id, user);
    return user;
  }

  private cloneUser(user: StoredUser) {
    return {
      ...user,
      createdAt: new Date(user.createdAt),
      lockedUntil: user.lockedUntil ? new Date(user.lockedUntil) : null,
    };
  }

  private cloneTimetable(timetable: StoredTimetable) {
    return {
      ...timetable,
      scoreBreakdown: { ...timetable.scoreBreakdown },
      savedAt: new Date(timetable.savedAt),
      createdAt: new Date(timetable.createdAt),
      updatedAt: new Date(timetable.updatedAt),
      courses: timetable.courses.map((course) => ({
        ...course,
        timeSlots: course.timeSlots.map((slot) => ({ ...slot })),
      })),
    };
  }

  private clean<T extends object>(value: T) {
    return Object.fromEntries(
      Object.entries(value).filter(([, entry]) => entry !== undefined),
    ) as T;
  }
}
