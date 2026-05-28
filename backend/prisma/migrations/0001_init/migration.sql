-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "CourseCategory" AS ENUM ('majorRequired', 'majorElective', 'coreLiberalArts', 'generalElective');

-- CreateEnum
CREATE TYPE "RatingSource" AS ENUM ('officialEstimate', 'userInput', 'reviewBacked');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "name" TEXT,
    "studentId" TEXT,
    "department" TEXT,
    "grade" INTEGER,
    "passwordHash" TEXT,
    "passwordSalt" TEXT,
    "failedLoginCount" INTEGER NOT NULL DEFAULT 0,
    "lockedUntil" TIMESTAMP(3),
    "socialProvider" TEXT,
    "providerUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "auth_sessions" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "revokedAt" TIMESTAMP(3),

    CONSTRAINT "auth_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_timetables" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "score" DOUBLE PRECISION NOT NULL,
    "scoreBreakdown" JSONB NOT NULL,
    "savedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "saved_timetables_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_timetable_courses" (
    "id" TEXT NOT NULL,
    "timetableId" TEXT NOT NULL,
    "externalId" TEXT NOT NULL,
    "courseCode" TEXT NOT NULL,
    "section" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "professor" TEXT NOT NULL,
    "credit" INTEGER NOT NULL,
    "rating" DOUBLE PRECISION NOT NULL,
    "difficulty" INTEGER NOT NULL,
    "hasTeamProject" BOOLEAN NOT NULL,
    "isMajorRequired" BOOLEAN NOT NULL,
    "category" "CourseCategory" NOT NULL,
    "ratingSource" "RatingSource" NOT NULL,
    "grade" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,

    CONSTRAINT "saved_timetable_courses_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "saved_timetable_course_slots" (
    "id" TEXT NOT NULL,
    "courseId" TEXT NOT NULL,
    "day" TEXT NOT NULL,
    "startHour" INTEGER NOT NULL,
    "endHour" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,

    CONSTRAINT "saved_timetable_course_slots_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "auth_sessions_tokenHash_key" ON "auth_sessions"("tokenHash");

-- CreateIndex
CREATE INDEX "auth_sessions_userId_expiresAt_idx" ON "auth_sessions"("userId", "expiresAt");

-- CreateIndex
CREATE INDEX "saved_timetables_userId_savedAt_idx" ON "saved_timetables"("userId", "savedAt" DESC);

-- CreateIndex
CREATE INDEX "saved_timetable_courses_timetableId_position_idx" ON "saved_timetable_courses"("timetableId", "position");

-- CreateIndex
CREATE INDEX "saved_timetable_course_slots_courseId_position_idx" ON "saved_timetable_course_slots"("courseId", "position");

-- AddForeignKey
ALTER TABLE "auth_sessions" ADD CONSTRAINT "auth_sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_timetables" ADD CONSTRAINT "saved_timetables_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_timetable_courses" ADD CONSTRAINT "saved_timetable_courses_timetableId_fkey" FOREIGN KEY ("timetableId") REFERENCES "saved_timetables"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_timetable_course_slots" ADD CONSTRAINT "saved_timetable_course_slots_courseId_fkey" FOREIGN KEY ("courseId") REFERENCES "saved_timetable_courses"("id") ON DELETE CASCADE ON UPDATE CASCADE;

