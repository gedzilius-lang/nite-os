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
exports.RadioController = void 0;
const common_1 = require("@nestjs/common");
const radio_service_1 = require("./radio.service");
let RadioController = class RadioController {
    constructor(radioService) {
        this.radioService = radioService;
    }
    async getNowPlaying() {
        return this.radioService.getNowPlaying();
    }
    async webhook(body, secret) {
        if (secret !== 'nite_radio_secret_key_999') {
            throw new common_1.UnauthorizedException('Invalid Radio Secret');
        }
        const meta = {
            artist: body.artist || 'Unknown Artist',
            title: body.title || 'Unknown Track',
            timestamp: new Date().toISOString()
        };
        return this.radioService.updateNowPlaying(meta);
    }
};
exports.RadioController = RadioController;
__decorate([
    (0, common_1.Get)('now-playing'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], RadioController.prototype, "getNowPlaying", null);
__decorate([
    (0, common_1.Post)('webhook'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, common_1.Query)('secret')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, String]),
    __metadata("design:returntype", Promise)
], RadioController.prototype, "webhook", null);
exports.RadioController = RadioController = __decorate([
    (0, common_1.Controller)('radio'),
    __metadata("design:paramtypes", [radio_service_1.RadioService])
], RadioController);
//# sourceMappingURL=radio.controller.js.map