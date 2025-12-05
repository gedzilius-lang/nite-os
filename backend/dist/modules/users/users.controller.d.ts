import { UsersService } from './users.service';
export declare class UsersController {
    private readonly service;
    constructor(service: UsersService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
