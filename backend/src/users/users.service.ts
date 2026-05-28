import { Injectable } from '@nestjs/common';

import { PrismaService } from '../prisma/prisma.service';
import { SyncUserDto } from './dto/sync-user.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async sync(input: SyncUserDto) {
    const user = await this.prisma.user.upsert({
      where: { id: input.id },
      update: {
        email: input.email,
        name: input.name,
        studentId: input.studentId,
        department: input.department,
        grade: input.grade,
      },
      create: {
        id: input.id,
        email: input.email,
        name: input.name,
        studentId: input.studentId,
        department: input.department,
        grade: input.grade,
        createdAt: input.createdAt ? new Date(input.createdAt) : undefined,
      },
    });

    return {
      ...user,
      createdAt: user.createdAt.toISOString(),
      updatedAt: user.updatedAt.toISOString(),
    };
  }
}
