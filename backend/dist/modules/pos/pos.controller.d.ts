import { PosService } from './pos.service';
export declare class PosController {
    private readonly service;
    constructor(service: PosService);
    healthCheck(): {
        status: string;
        service: string;
        timestamp: string;
    };
}
