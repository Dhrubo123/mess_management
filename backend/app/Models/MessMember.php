<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MessMember extends Model
{
    protected $fillable = [
        'mess_id',
        'user_id',
        'role',
        'room_label',
        'monthly_seat_rent',
        'is_active',
        'joined_at',
        'left_at',
    ];

    protected function casts(): array
    {
        return [
            'monthly_seat_rent' => 'float',
            'is_active' => 'boolean',
            'joined_at' => 'datetime',
            'left_at' => 'datetime',
        ];
    }

    public function mess(): BelongsTo
    {
        return $this->belongsTo(Mess::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
