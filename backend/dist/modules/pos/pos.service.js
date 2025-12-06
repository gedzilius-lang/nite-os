"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.PosService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const pos_transaction_entity_1 = require("./pos-transaction.entity");
const user_entity_1 = require("../users/user.entity");
const market_item_entity_1 = require("../market/market-item.entity");
const nitecoin_transaction_entity_1 = require("../nitecoin/nitecoin-transaction.entity");
const analytics_service_1 = require("../analytics/analytics.service");
let PosService = class PosService {
    constructor(posRepo, userRepo, itemRepo, nitecoinRepo, analytics) {
        this.posRepo = posRepo;
        this.userRepo = userRepo;
        this.itemRepo = itemRepo;
        this.nitecoinRepo = nitecoinRepo;
        this.analytics = analytics;
    }
    async checkout(venueId, dto, staffUser) {
        if (staffUser.role !== 'NITECORE_ADMIN' && staffUser.venueId !== venueId) {
            throw new common_1.ForbiddenException('You are not authorized for this venue');
        }
        const customer = await this.userRepo.findOne({ where: { nitetapId: dto.nitetapId } });
        if (!customer)
            throw new common_1.NotFoundException('NiteTap ID not found');
        const itemIds = dto.items.map((i) => i.itemId);
        const dbItems = await this.itemRepo.find({ where: { id: (0, typeorm_2.In)(itemIds) } });
        let totalChf = 0;
        let totalNite = 0;
        for (const reqItem of dto.items) {
            const dbItem = dbItems.find((i) => i.id === reqItem.itemId);
            if (!dbItem)
                continue;
            totalChf += Number(dbItem.priceChf) * reqItem.count;
            totalNite += Number(dbItem.priceNite) * reqItem.count;
        }
        if (totalNite === 0 && totalChf === 0)
            throw new common_1.BadRequestException('No valid items');
        if (customer.niteBalance < totalNite)
            throw new common_1.BadRequestException(`Insufficient Nitecoin`);
        customer.niteBalance = Number(customer.niteBalance) - totalNite;
        await this.userRepo.save(customer);
        if (totalNite > 0) {
            await this.nitecoinRepo.save({
                userId: customer.id,
                venueId: venueId,
                amount: -totalNite,
                type: 'SPEND'
            });
        }
        const receipt = await this.posRepo.save({
            venueId: venueId,
            staffId: staffUser.userId,
            userId: customer.id,
            nitetapId: dto.nitetapId,
            totalChf: totalChf,
            totalNite: totalNite,
            status: 'COMPLETED'
        });
        this.analytics.logEvent('POS', 'CHECKOUT', customer.id, {
            venueId,
            totalNite,
            receiptId: receipt.id
        });
        return {
            success: true,
            newBalance: customer.niteBalance,
            receiptId: receipt.id
        };
    }
};
exports.PosService = PosService;
exports.PosService = PosService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(pos_transaction_entity_1.PosTransaction)),
    __param(1, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __param(2, (0, typeorm_1.InjectRepository)(market_item_entity_1.MarketItem)),
    __param(3, (0, typeorm_1.InjectRepository)(nitecoin_transaction_entity_1.NitecoinTransaction)),
    __metadata("design:paramtypes", [typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        typeorm_2.Repository,
        analytics_service_1.AnalyticsService])
], PosService);
//# sourceMappingURL=pos.service.js.map