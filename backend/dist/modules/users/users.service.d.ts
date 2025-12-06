import { Repository } from 'typeorm';
import { User } from './user.entity';
export declare class UsersService {
    private userRepo;
    constructor(userRepo: Repository<User>);
    getHealth(): {
        status: string;
        service: string;
        timestamp: string;
    };
    createDemoUser(): Promise<{
        user: User;
        admin: string;
    }>;
}
