import { NitecoinService } from './nitecoin.service';
export declare class NitecoinController {
    private readonly service;
    constructor(service: NitecoinService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
