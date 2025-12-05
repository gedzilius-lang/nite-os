import { VenuesService } from './venues.service';
export declare class VenuesController {
    private readonly service;
    constructor(service: VenuesService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
