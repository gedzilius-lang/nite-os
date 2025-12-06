import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // Security Headers
  app.use(helmet());
  
  // CORS (Allow Frontend)
  app.enableCors({
    origin: ['http://localhost', 'http://127.0.0.1'], // Adjust for real domain later
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  });

  app.setGlobalPrefix('api');
  await app.listen(3000);
  console.log('NiteOS V8 Backend is live (Secured)');
}
bootstrap();
