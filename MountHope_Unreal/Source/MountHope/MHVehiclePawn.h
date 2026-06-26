#pragma once

#include "CoreMinimal.h"
#include "WheeledVehiclePawn.h"
#include "MHVehiclePawn.generated.h"

UCLASS()
class MOUNTHOPE_API AMHVehiclePawn : public AWheeledVehiclePawn
{
    GENERATED_BODY()

public:
    AMHVehiclePawn();

    UFUNCTION(BlueprintPure, Category = "Mount Hope|Vehicle")
    bool CanDriverEnter(const APawn* CandidateDriver) const;

protected:
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Mount Hope|Vehicle")
    float EntryRadiusMeters = 3.5f;
};
