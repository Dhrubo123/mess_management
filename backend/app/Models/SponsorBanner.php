<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SponsorBanner extends Model
{
    protected $fillable = [
        'sponsor_name',
        'headline',
        'subtitle',
        'cta_label',
        'cta_value',
        'target_area',
        'badge_text',
        'is_active',
        'clicks',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'clicks' => 'integer',
        ];
    }
}
