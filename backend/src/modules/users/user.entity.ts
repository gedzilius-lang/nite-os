import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ nullable: true })
  externalId: string;

  @Column({ unique: true, nullable: true })
  nitetapId: string;

  // New Credential Fields
  @Column({ unique: true, nullable: true })
  username: string;

  @Column({ nullable: true, select: false }) // Select false hides it by default
  password: string;

  @Column({ nullable: true })
  apiKey: string;

  @Column({ default: 'USER' })
  role: string; // USER, STAFF, VENUE_ADMIN, NITECORE_ADMIN

  @Column({ nullable: true })
  venueId: number;

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
