<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Str;

class Mess extends Model
{
    protected $fillable = [
        'name',
        'invite_code',
        'city',
        'area',
        'address',
        'meal_cutoff_time',
        'has_breakfast',
        'facilities',
        'food_mode',
        'default_breakfast',
        'default_lunch',
        'default_dinner',
        'is_pro',
        'pro_expires_at',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'has_breakfast' => 'boolean',
            'facilities' => 'array',
            'default_breakfast' => 'float',
            'default_lunch' => 'float',
            'default_dinner' => 'float',
            'is_pro' => 'boolean',
            'pro_expires_at' => 'datetime',
        ];
    }

    public static function generateInviteCode(): string
    {
        do {
            $code = strtoupper(Str::random(6));
        } while (self::where('invite_code', $code)->exists());

        return $code;
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function members(): HasMany
    {
        return $this->hasMany(MessMember::class);
    }

    public function activeMembers(): HasMany
    {
        return $this->hasMany(MessMember::class)->where('is_active', true);
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'mess_members')
            ->withPivot(['role', 'room_label', 'monthly_seat_rent', 'is_active', 'joined_at', 'left_at'])
            ->withTimestamps();
    }

    public function months(): HasMany
    {
        return $this->hasMany(MessMonth::class);
    }

    public function seatListings(): HasMany
    {
        return $this->hasMany(SeatListing::class);
    }

    public function currentMonth(): MessMonth
    {
        $now = now();
        $managerId = $this->activeMembers()->where('role', 'manager')->value('user_id') ?? $this->created_by;

        return $this->months()->firstOrCreate(
            ['year' => (int) $now->year, 'month' => (int) $now->month],
            ['manager_id' => $managerId, 'status' => 'open']
        );
    }
}
