#pragma once

#include "CoreMinimal.h"
#include "Subsystems/GameInstanceSubsystem.h"
#include "MHGameStateSubsystem.generated.h"

UENUM(BlueprintType)
enum class EMHWeatherState : uint8
{
    Clear = 0,
    DenseFog = 1,
    CoastalRain = 2,
    Noreaster = 3
};

USTRUCT(BlueprintType)
struct FMHBusinessRecord
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    FString Id;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    FString Name;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    int32 Cost = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    int32 DailyIncome = 0;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    FVector WorldLocation = FVector::ZeroVector;
};

UCLASS(BlueprintType)
class MOUNTHOPE_API UMHGameStateSubsystem : public UGameInstanceSubsystem
{
    GENERATED_BODY()

public:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Player")
    int32 Cash = 250;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Player")
    float Health = 100.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Hostility")
    float PoliceHeat = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Hostility")
    float FactionHeat = 0.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    EMHWeatherState Weather = EMHWeatherState::Clear;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    TArray<FMHBusinessRecord> Businesses;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Economy")
    TSet<FName> OwnedBusinessIds;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Hostility")
    void AddHeat(float PoliceDelta, float FactionDelta);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Hostility")
    void DecayHeat(float DeltaSeconds, float RatePerSecond = 0.05f);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Player")
    void AddCash(int32 Delta);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Player")
    void ApplyDamage(float Damage);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Weather")
    void CycleWeather();

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Economy")
    bool BuyBusiness(const FString& BusinessId);

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Economy")
    int32 GetPassiveDailyIncome() const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Economy")
    bool LoadBusinessesFromJson(const FString& RelativeOrAbsolutePath);

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    bool SaveToSlot(const FString& SlotName = TEXT("MountHopeSlot"), int32 UserIndex = 0) const;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Save")
    bool LoadFromSlot(const FString& SlotName = TEXT("MountHopeSlot"), int32 UserIndex = 0);
};
