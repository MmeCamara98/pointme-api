<?php

namespace App\Filament\Admin\Resources\Stagiaires\Pages;

use App\Filament\Admin\Resources\Stagiaires\StagiaireResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditStagiaire extends EditRecord
{
    protected static string $resource = StagiaireResource::class;

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()->label('Supprimer le Stagiaire'),
        ];
    }
}
