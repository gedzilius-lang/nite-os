"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const core_1 = require("@nestjs/core");
const app_module_1 = require("./app.module");
const helmet_1 = require("helmet");
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.use((0, helmet_1.default)());
    app.enableCors({
        origin: ['http://localhost', 'http://127.0.0.1'],
        methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    });
    app.setGlobalPrefix('api');
    await app.listen(3000);
    console.log('NiteOS V8 Backend is live (Secured)');
}
bootstrap();
//# sourceMappingURL=main.js.map