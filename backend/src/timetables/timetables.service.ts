import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  CourseCategory as PrismaCourseCategory,
  Prisma,
  RatingSource as PrismaRatingSource,
} from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { CreateTimetableDto } from './dto/create-timetable.dto';
import { RenameTimetableDto } from './dto/rename-timetable.dto';
import { TimetableCourseDto } from './dto/timetable-course.dto';

const timetableInclude = {
  courses: {
    orderBy: { position: 'asc' as const },
    include: {
      timeSlots: {
        orderBy: { position: 'asc' as const },
      },
    },
  },
};

type TimetableRecord = Prisma.SavedTimetableGetPayload<{
  include: typeof timetableInclude;
}>;

@Injectable()
export class TimetablesService {
  constructor(private readonly prisma: PrismaService) {}

  async listByUser(userId: string) {
    await this.ensureUser(userId);

    const timetables = await this.prisma.savedTimetable.findMany({
      where: { userId },
      orderBy: [{ savedAt: 'desc' }, { createdAt: 'desc' }],
      include: timetableInclude,
    });

    return timetables.map((timetable) => this.toResponse(timetable));
  }

  async create(userId: string, input: CreateTimetableDto) {
    await this.ensureUser(userId);

    const timetable = (await this.prisma.savedTimetable.create({
      data: {
        userId,
        name: this.normalizeName(input.name),
        score: input.score,
        scoreBreakdown: this.normalizeIncomingScoreBreakdown(
          input.scoreBreakdown,
        ),
        courses: {
          create: input.courses.map((course, position) =>
            this.toCourseCreateInput(course, position),
          ),
        },
      },
      include: timetableInclude,
    })) as TimetableRecord;

    return this.toResponse(timetable);
  }

  async rename(userId: string, id: string, input: RenameTimetableDto) {
    const updated = await this.prisma.savedTimetable.updateMany({
      where: { id, userId },
      data: {
        name: this.normalizeName(input.name),
      },
    });

    if (updated.count == 0) {
      throw new NotFoundException('Timetable not found.');
    }

    const timetable = await this.prisma.savedTimetable.findUnique({
      where: { id },
      include: timetableInclude,
    });

    if (!timetable) {
      throw new NotFoundException('Timetable not found.');
    }

    return this.toResponse(timetable);
  }

  async delete(userId: string, id: string) {
    const deleted = await this.prisma.savedTimetable.deleteMany({
      where: { id, userId },
    });

    if (deleted.count == 0) {
      throw new NotFoundException('Timetable not found.');
    }
  }

  private async ensureUser(userId: string) {
    await this.prisma.user.upsert({
      where: { id: userId },
      update: {},
      create: { id: userId },
    });
  }

  private toCourseCreateInput(
    course: TimetableCourseDto,
    position: number,
  ): Prisma.SavedTimetableCourseCreateWithoutTimetableInput {
    const [courseCode, section = '001'] = course.id.split('-');
    this.assertValidTimeSlots(course);

    return {
      externalId: course.id,
      courseCode,
      section,
      name: course.name,
      professor: course.professor,
      credit: course.credit,
      rating: course.rating,
      difficulty: course.difficulty,
      hasTeamProject: course.hasTeamProject,
      isMajorRequired: course.isMajorRequired,
      category: course.category as PrismaCourseCategory,
      ratingSource: course.ratingSource as PrismaRatingSource,
      grade: course.grade,
      position,
      timeSlots: {
        create: course.timeSlots.map((slot, slotIndex) => ({
          day: slot.day,
          startHour: slot.startHour,
          endHour: slot.endHour,
          position: slotIndex,
        })),
      },
    };
  }

  private toResponse(timetable: TimetableRecord) {
    return {
      id: timetable.id,
      userId: timetable.userId,
      name: timetable.name,
      score: timetable.score,
      scoreBreakdown: this.normalizeScoreBreakdown(timetable.scoreBreakdown),
      savedAt: timetable.savedAt.toISOString(),
      courses: timetable.courses.map((course) => ({
        id: course.externalId,
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
        timeSlots: course.timeSlots.map((slot) => ({
          day: slot.day,
          startHour: slot.startHour,
          endHour: slot.endHour,
        })),
      })),
    };
  }

  private normalizeName(value: string) {
    const trimmed = value.trim();
    return trimmed.length === 0 ? 'Saved Timetable' : trimmed;
  }

  private normalizeIncomingScoreBreakdown(value: Record<string, unknown>) {
    const entries = Object.entries(value);
    if (entries.length > 30) {
      throw new BadRequestException('Score breakdown has too many entries.');
    }

    return Object.fromEntries(
      entries.map(([key, raw]) => {
        const trimmedKey = key.trim();
        if (trimmedKey.length === 0 || trimmedKey.length > 40) {
          throw new BadRequestException('Score breakdown key is invalid.');
        }
        if (typeof raw !== 'number' || !Number.isFinite(raw)) {
          throw new BadRequestException(
            'Score breakdown values must be finite numbers.',
          );
        }
        return [trimmedKey, raw];
      }),
    );
  }

  private assertValidTimeSlots(course: TimetableCourseDto) {
    for (const slot of course.timeSlots) {
      if (slot.endHour <= slot.startHour) {
        throw new BadRequestException(
          'Course time slot endHour must be greater than startHour.',
        );
      }
    }
  }

  private normalizeScoreBreakdown(
    value: Prisma.JsonValue,
  ): Record<string, number> {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      return {};
    }

    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, raw]) => [
        key,
        Number(raw ?? 0),
      ]),
    );
  }
}
