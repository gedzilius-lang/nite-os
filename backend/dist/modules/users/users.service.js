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
exports.UsersService = void 0;
const common_1 = require("@nestjs/common");
const typeorm_1 = require("@nestjs/typeorm");
const typeorm_2 = require("typeorm");
const user_entity_1 = require("./user.entity");
const bcrypt = require("bcryptjs");
let UsersService = class UsersService {
    constructor(userRepo) {
        this.userRepo = userRepo;
    }
    getHealth() {
        return { status: 'ok', service: 'users', timestamp: new Date().toISOString() };
    }
    async createDemoUser() {
        let user = await this.userRepo.findOne({ where: { nitetapId: 'TAP-TEST' } });
        if (!user) {
            user = this.userRepo.create({
                nitetapId: 'TAP-TEST',
                niteBalance: 1000,
                xp: 100,
                level: 5,
                role: 'USER'
            });
            await this.userRepo.save(user);
        }
        let admin = await this.userRepo.findOne({ where: { username: 'admin' } });
        if (!admin) {
            const hash = await bcrypt.hash('admin123', 10);
            admin = this.userRepo.create({
                username: 'admin',
                password: hash,
                role: 'VENUE_ADMIN',
                venueId: 1,
                niteBalance: 0
            });
            await this.userRepo.save(admin);
        }
        return { user, admin: 'admin / admin123' };
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, typeorm_1.InjectRepository)(user_entity_1.User)),
    __metadata("design:paramtypes", [typeorm_2.Repository])
], UsersService);
//# sourceMappingURL=users.service.js.map