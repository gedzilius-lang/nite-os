import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  externalId: string; // e.g. Auth0 or generic external ID

  @Column({ unique: true, nullable: true })
  nitetapId: string; // Physical card ID

  @Column({ nullable: true })
  apiKey: string; // For programmatic access

  @Column({ default: 'USER' })
  role: string; // USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN

  @Column({ nullable: true })
  venueId: number; // Linked venue (if staff/admin)

  @Column({ default: 0 })
  xp: number;

  @Column({ default: 1 })
  level: number;

  @Column({ type: 'decimal', default: 0 })
  niteBalance: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
