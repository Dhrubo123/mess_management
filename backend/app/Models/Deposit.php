<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Deposit extends Model
{
    protected $fillable = [
        'mess_month_id',
        'user_id',
        'amount',
        'deposit_type',
        'payment_method',
        'reference',
        'deposit_date',
        'recorded_by',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'float',
            'deposit_date' => 'date:Y-m-d',
        ];
    }

    public function messMonth(): BelongsTo
    {
        return $this->belongsTo(MessMonth::class);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function recorder(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
