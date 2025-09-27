<?php

namespace App\Filament\Admin\Resources\Coaches\Pages;

use App\Filament\Admin\Resources\Coaches\CoachResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListCoaches extends ListRecords
{
    protected static string $resource = CoachResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()->label('Ajouter un Coach'),
        ];
    }
}
