import { AuthService } from './auth.service';
export declare class AuthController {
    private readonly service;
    constructor(service: AuthService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
