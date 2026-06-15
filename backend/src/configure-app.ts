import { ValidationPipe, type INestApplication } from '@nestjs/common';
import helmet from 'helmet';

export function configureApp(app: INestApplication) {
  app.use(helmet());

  app.enableCors({
    origin: process.env.CORS_ORIGIN
      ? process.env.CORS_ORIGIN.split(',').map((value) => value.trim())
      : true,
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
}
