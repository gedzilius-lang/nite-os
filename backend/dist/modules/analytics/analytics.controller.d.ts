import { AnalyticsService } from './analytics.service';
export declare class AnalyticsController {
    private readonly service;
    constructor(service: AnalyticsService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
