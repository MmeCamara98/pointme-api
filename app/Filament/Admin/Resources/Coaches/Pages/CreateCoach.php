<?php

namespace App\Filament\Admin\Resources\Coaches\Pages;

use App\Filament\Admin\Resources\Coaches\CoachResource;
use Filament\Resources\Pages\CreateRecord;

class CreateCoach extends CreateRecord
{
    // Suppression de getFormActions car DeleteAction ne peut pas être utilisé sur une page de création
    // Un enregistrement doit exister pour pouvoir être supprimé
    protected static string $resource = CoachResource::class;
}
