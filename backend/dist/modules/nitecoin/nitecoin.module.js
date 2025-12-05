"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.NitecoinModule = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const nitecoin_controller_1 = require("./nitecoin.controller");
const nitecoin_service_1 = require("./nitecoin.service");
const nitecoin_transaction_entity_1 = require("./nitecoin-transaction.entity");
let NitecoinModule = class NitecoinModule {
};
exports.NitecoinModule = NitecoinModule;
exports.NitecoinModule = NitecoinModule = __decorate([
    (0, common_1.Module)({
        imports: [typeorm_1.TypeOrmModule.forFeature([nitecoin_transaction_entity_1.NitecoinTransaction])],
        controllers: [nitecoin_controller_1.NitecoinController],
        providers: [nitecoin_service_1.NitecoinService],
        exports: [typeorm_1.TypeOrmModule],
    })
], NitecoinModule);
//# sourceMappingURL=nitecoin.module.js.map