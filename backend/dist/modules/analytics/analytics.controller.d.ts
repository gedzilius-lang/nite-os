import { AnalyticsService } from './analytics.service';
export declare class AnalyticsController {
    private readonly service;
    constructor(service: AnalyticsService);
    health(): {
        status: string;
        service: string;
        db: string;
    };
    getLogs(): Promise<(import("mongoose").Document<unknown, {}, import("mongoose").Document<unknown, {}, import("./log.schema").Log, {}, {}> & import("./log.schema").Log & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    }, {}, {}> & import("mongoose").Document<unknown, {}, import("./log.schema").Log, {}, {}> & import("./log.schema").Log & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    } & Required<{
        _id: import("mongoose").Types.ObjectId;
    }>)[]>;
}
