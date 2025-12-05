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
exports.MarketService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const market_item_entity_1 = require("./market-item.entity");
let MarketService = class MarketService {
    constructor(itemRepo) {
        this.itemRepo = itemRepo;
    }
    async getItemsByVenue(venueId) {
        return this.itemRepo.find({
            where: { venueId, active: true },
            order: { title: 'ASC' },
        });
    }
    async seedDemoData(venueId) {
        const items = [
            { title: 'Beer', priceChf: 8.0, priceNite: 50, venueId, active: true },
            { title: 'Long Drink', priceChf: 15.0, priceNite: 120, venueId, active: true },
            { title: 'Shot', priceChf: 5.0, priceNite: 30, venueId, active: true },
            { title: 'VIP Table', priceChf: 200.0, priceNite: 2000, venueId, active: true },
        ];
        await this.itemRepo.delete({ venueId });
        return this.itemRepo.save(items);
    }
};
exports.MarketService = MarketService;
exports.MarketService = MarketService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(market_item_entity_1.MarketItem)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], MarketService);
//# sourceMappingURL=market.service.js.map