export const courseCategoryValues = [
  'majorRequired',
  'majorElective',
  'coreLiberalArts',
  'balancedLiberalArts',
  'generalElective',
] as const;

export const ratingSourceValues = [
  'officialEstimate',
  'userInput',
  'reviewBacked',
] as const;

export type CourseCategoryValue = (typeof courseCategoryValues)[number];
export type RatingSourceValue = (typeof ratingSourceValues)[number];
