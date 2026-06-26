#pragma once

#include "CoreMinimal.h"
#include "WheeledVehiclePawn.h"
#include "MountHopeVehiclePawn.generated.h"

UCLASS(BlueprintType)
class MOUNTHOPE_API AMountHopeVehiclePawn : public AWheeledVehiclePawn
{
    GENERATED_BODY()

public:
    AMountHopeVehiclePawn();

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Vehicle")
    FString VehicleLabel = TEXT("Townie");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "MountHope|Vehicle")
    FName DriverSeatSocket = TEXT("DriverSeat");

    UFUNCTION(BlueprintPure, Category = "MountHope|Vehicle")
    FVector GetSuggestedExitLocation() const;
};
