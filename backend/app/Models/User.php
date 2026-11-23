<?php

namespace App\Models;

use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'phone', 'locale', 'is_admin', 'password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'is_admin' => 'boolean',
            'password' => 'hashed',
        ];
    }

    public function messes(): BelongsToMany
    {
        return $this->belongsToMany(Mess::class, 'mess_members')
            ->withPivot(['role', 'room_label', 'monthly_seat_rent', 'is_active', 'joined_at', 'left_at'])
            ->withTimestamps();
    }

    public function memberships(): HasMany
    {
        return $this->hasMany(MessMember::class);
    }

    public function seatListings(): HasMany
    {
        return $this->hasMany(SeatListing::class, 'posted_by');
    }
}
