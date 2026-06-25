#pragma once

#include "CoreMinimal.h"
#include "UObject/Interface.h"
#include "MHInteractable.generated.h"

UINTERFACE(BlueprintType)
class MOUNTHOPE_API UMHInteractable : public UInterface
{
    GENERATED_BODY()
};

class MOUNTHOPE_API IMHInteractable
{
    GENERATED_BODY()

public:
    UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Mount Hope|Interaction")
    FText GetInteractionPrompt() const;

    UFUNCTION(BlueprintNativeEvent, BlueprintCallable, Category = "Mount Hope|Interaction")
    void Interact(APawn* InstigatorPawn);
};
