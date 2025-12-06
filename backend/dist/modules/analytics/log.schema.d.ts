import { HydratedDocument } from 'mongoose';
export type LogDocument = HydratedDocument<Log>;
export declare class Log {
    category: string;
    action: string;
    meta: any;
    userId: number;
}
export declare const LogSchema: import("mongoose").Schema<Log, import("mongoose").Model<Log, any, any, any, import("mongoose").Document<unknown, any, Log, any, {}> & Log & {
    _id: import("mongoose").Types.ObjectId;
} & {
    __v: number;
}, any>, {}, {}, {}, {}, import("mongoose").DefaultSchemaOptions, Log, import("mongoose").Document<unknown, {}, import("mongoose").FlatRecord<Log>, {}, import("mongoose").ResolveSchemaOptions<import("mongoose").DefaultSchemaOptions>> & import("mongoose").FlatRecord<Log> & {
    _id: import("mongoose").Types.ObjectId;
} & {
    __v: number;
}>;
