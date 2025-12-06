import { RadioService } from './radio.service';
export declare class RadioController {
    private readonly radioService;
    constructor(radioService: RadioService);
    getNowPlaying(): Promise<unknown>;
    webhook(body: any, secret: string): Promise<{
        status: string;
        meta: any;
    }>;
}
