#include "MHRadioSubsystem.h"

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
FString ResolvePath(const FString& RelativeOrAbsolutePath)
{
    if (FPaths::FileExists(RelativeOrAbsolutePath))
    {
        return RelativeOrAbsolutePath;
    }

    return FPaths::ConvertRelativePathToFull(FPaths::ProjectDir() / RelativeOrAbsolutePath);
}
}

bool UMHRadioSubsystem::LoadStationsFromJson(const FString& RelativeOrAbsolutePath)
{
    const FString FullPath = ResolvePath(RelativeOrAbsolutePath);
    FString RawJson;
    if (!FFileHelper::LoadFileToString(RawJson, *FullPath))
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Unable to load radio stations JSON: %s"), *FullPath);
        return false;
    }

    TSharedPtr<FJsonObject> RootObject;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(RawJson);
    if (!FJsonSerializer::Deserialize(Reader, RootObject) || !RootObject.IsValid())
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Invalid radio stations JSON: %s"), *FullPath);
        return false;
    }

    const TArray<TSharedPtr<FJsonValue>>* StationsArray = nullptr;
    if (!RootObject->TryGetArrayField(TEXT("stations"), StationsArray) || !StationsArray)
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Missing 'stations' field in %s"), *FullPath);
        return false;
    }

    Stations.Reset();
    Stations.Reserve(StationsArray->Num());
    for (const TSharedPtr<FJsonValue>& Value : *StationsArray)
    {
        const TSharedPtr<FJsonObject> Object = Value->AsObject();
        if (!Object.IsValid())
        {
            continue;
        }

        FMHRadioStation Station;
        Station.Id = FName(*Object->GetStringField(TEXT("id")));
        Station.DisplayName = Object->GetStringField(TEXT("name"));
        Object->TryGetStringField(TEXT("tagline"), Station.Tagline);
        Object->TryGetStringField(TEXT("dj"), Station.DjName);
        Object->TryGetStringField(TEXT("genre"), Station.Genre);
        Object->TryGetStringField(TEXT("voFolder"), Station.VoContentFolder);
        Object->TryGetStringField(TEXT("jingleFolder"), Station.JingleContentFolder);

        const TArray<TSharedPtr<FJsonValue>>* SongsArray = nullptr;
        if (Object->TryGetArrayField(TEXT("songs"), SongsArray) && SongsArray)
        {
            Station.Songs.Reserve(SongsArray->Num());
            for (const TSharedPtr<FJsonValue>& SongValue : *SongsArray)
            {
                Station.Songs.Add(SongValue->AsString());
            }
        }

        if (!Station.Id.IsNone())
        {
            Stations.Add(MoveTemp(Station));
        }
    }

    CurrentStationIndex = INDEX_NONE;
    CurrentSongIndex = 0;

    UE_LOG(LogTemp, Log, TEXT("MountHope: Loaded %d radio stations"), Stations.Num());
    return Stations.Num() > 0;
}

void UMHRadioSubsystem::TuneToStation(FName StationId)
{
    if (StationId.IsNone())
    {
        TurnOff();
        return;
    }

    for (int32 Index = 0; Index < Stations.Num(); ++Index)
    {
        if (Stations[Index].Id == StationId)
        {
            CurrentStationIndex = Index;
            CurrentSongIndex = 0;
            OnStationChanged.Broadcast(StationId);
            BroadcastCurrentSong();
            return;
        }
    }
}

void UMHRadioSubsystem::NextStation()
{
    if (Stations.Num() == 0)
    {
        return;
    }

    CurrentStationIndex = (CurrentStationIndex + 1) % Stations.Num();
    CurrentSongIndex = 0;
    OnStationChanged.Broadcast(Stations[CurrentStationIndex].Id);
    BroadcastCurrentSong();
}

void UMHRadioSubsystem::TurnOff()
{
    CurrentStationIndex = INDEX_NONE;
    CurrentSongIndex = 0;
    OnStationChanged.Broadcast(NAME_None);
}

void UMHRadioSubsystem::AdvanceSong()
{
    if (!Stations.IsValidIndex(CurrentStationIndex) || Stations[CurrentStationIndex].Songs.Num() == 0)
    {
        return;
    }

    CurrentSongIndex = (CurrentSongIndex + 1) % Stations[CurrentStationIndex].Songs.Num();
    BroadcastCurrentSong();
}

bool UMHRadioSubsystem::GetCurrentStation(FMHRadioStation& OutStation) const
{
    if (!Stations.IsValidIndex(CurrentStationIndex))
    {
        return false;
    }

    OutStation = Stations[CurrentStationIndex];
    return true;
}

FString UMHRadioSubsystem::GetCurrentSong() const
{
    if (!Stations.IsValidIndex(CurrentStationIndex))
    {
        return FString();
    }

    const FMHRadioStation& Station = Stations[CurrentStationIndex];
    return Station.Songs.IsValidIndex(CurrentSongIndex) ? Station.Songs[CurrentSongIndex] : FString();
}

void UMHRadioSubsystem::BroadcastCurrentSong()
{
    if (!Stations.IsValidIndex(CurrentStationIndex))
    {
        return;
    }

    const FMHRadioStation& Station = Stations[CurrentStationIndex];
    if (Station.Songs.IsValidIndex(CurrentSongIndex))
    {
        OnSongChanged.Broadcast(Station.Id, Station.Songs[CurrentSongIndex]);
    }
}
