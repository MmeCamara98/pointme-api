<?php

namespace App\Filament\Admin\Resources\Coaches\Pages;

use App\Filament\Admin\Resources\Coaches\CoachResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditCoach extends EditRecord
{
    protected static string $resource = CoachResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()->label('Supprimer le Coach'),
        ];
    }
}
