import { PosService, CheckoutDto } from './pos.service';
export declare class PosController {
    private readonly service;
    constructor(service: PosService);
    checkout(venueId: string, dto: CheckoutDto, user: any): Promise<{
        success: boolean;
        newBalance: number;
        receiptId: number;
    }>;
    health(): {
        status: string;
        service: string;
    };
}
