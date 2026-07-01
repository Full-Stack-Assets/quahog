#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHRadioSubsystem.generated.h"

DECLARE_DYNAMIC_MULTICAST_DELEGATE_OneParam(FMHOnStationChanged, FName, StationId);
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FMHOnSongChanged, FName, StationId, FString, SongTitle);

USTRUCT(BlueprintType)
struct FMHRadioStation
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FName Id;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FString DisplayName;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FString Tagline;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FString DjName;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FString Genre;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    TArray<FString> Songs;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FString VoContentFolder;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    FString JingleContentFolder;
};

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHRadioSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Radio")
    FMHOnStationChanged OnStationChanged;

    UPROPERTY(BlueprintAssignable, Category = "Mount Hope|Radio")
    FMHOnSongChanged OnSongChanged;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Radio")
    TArray<FMHRadioStation> Stations;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Radio")
    bool LoadStationsFromJson(const FString& RelativeOrAbsolutePath);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Radio")
    void TuneToStation(FName StationId);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Radio")
    void NextStation();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Radio")
    void TurnOff();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Radio")
    void AdvanceSong();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Radio")
    bool IsOff() const { return CurrentStationIndex == INDEX_NONE; }

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Radio")
    bool GetCurrentStation(FMHRadioStation& OutStation) const;

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Radio")
    FString GetCurrentSong() const;

private:
    UPROPERTY()
    int32 CurrentStationIndex = INDEX_NONE;

    UPROPERTY()
    int32 CurrentSongIndex = 0;

    void BroadcastCurrentSong();
};
