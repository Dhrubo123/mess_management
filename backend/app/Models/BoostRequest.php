<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BoostRequest extends Model
{
    protected $fillable = [
        'seat_listing_id',
        'user_id',
        'amount',
        'payment_method',
        'sender_phone',
        'trx_id',
        'duration_days',
        'status',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'duration_days' => 'integer',
            'reviewed_at' => 'datetime',
        ];
    }

    public function seatListing(): BelongsTo
    {
        return $this->belongsTo(SeatListing::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
