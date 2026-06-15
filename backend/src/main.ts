import 'reflect-metadata';

import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';
import { configureApp } from './configure-app';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableShutdownHooks();
  configureApp(app);

  const port = Number(process.env.PORT ?? '3001');
  await app.listen(port);
  console.log(`Class Finder backend listening on http://localhost:${port}`);
}

bootstrap();
