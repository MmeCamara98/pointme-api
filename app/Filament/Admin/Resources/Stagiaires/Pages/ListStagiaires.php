<?php

namespace App\Filament\Admin\Resources\Stagiaires\Pages;

use App\Filament\Admin\Resources\Stagiaires\StagiaireResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;

class ListStagiaires extends ListRecords
{
    protected static string $resource = StagiaireResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make()->label('Ajouter un Stagiaire'),
        ];
    }
}
