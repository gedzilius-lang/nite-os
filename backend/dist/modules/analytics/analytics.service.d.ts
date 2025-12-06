import { Model } from 'mongoose';
import { Log, LogDocument } from './log.schema';
export declare class AnalyticsService {
    private logModel;
    constructor(logModel: Model<LogDocument>);
    getHealth(): {
        status: string;
        service: string;
        db: string;
    };
    logEvent(category: string, action: string, userId: number, meta?: any): Promise<import("mongoose").Document<unknown, {}, import("mongoose").Document<unknown, {}, Log, {}, {}> & Log & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    }, {}, {}> & import("mongoose").Document<unknown, {}, Log, {}, {}> & Log & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    } & Required<{
        _id: import("mongoose").Types.ObjectId;
    }>>;
    getRecentLogs(limit?: number): Promise<(import("mongoose").Document<unknown, {}, import("mongoose").Document<unknown, {}, Log, {}, {}> & Log & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    }, {}, {}> & import("mongoose").Document<unknown, {}, Log, {}, {}> & Log & {
        _id: import("mongoose").Types.ObjectId;
    } & {
        __v: number;
    } & Required<{
        _id: import("mongoose").Types.ObjectId;
    }>)[]>;
}
