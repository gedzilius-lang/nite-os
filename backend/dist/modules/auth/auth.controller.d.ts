import { AuthService } from './auth.service';
export declare class AuthController {
    private authService;
    constructor(authService: AuthService);
    login(loginDto: any): Promise<{
        access_token: string;
        user: {
            username: any;
            sub: any;
            role: any;
            venueId: any;
        };
    }>;
    getProfile(req: any): Promise<import("../users/user.entity").User>;
}
