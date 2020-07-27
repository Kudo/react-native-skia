/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <React/RCTParagraphComponentAccessibilityProvider.h>
#import <React/RCTParagraphComponentView.h>

#import <XCTest/XCTest.h>
#import <react/attributedstring/AttributedString.h>
#import <react/attributedstring/ParagraphAttributes.h>
#import <react/attributedstring/TextAttributes.h>
#import <react/componentregistry/ComponentDescriptorProviderRegistry.h>
#import <react/components/root/RootComponentDescriptor.h>
#import <react/components/text/ParagraphComponentDescriptor.h>
#import <react/components/text/ParagraphShadowNode.h>
#import <react/components/text/ParagraphState.h>
#import <react/components/text/RawTextComponentDescriptor.h>
#import <react/components/text/RawTextShadowNode.h>
#import <react/components/text/TextComponentDescriptor.h>
#import <react/components/text/TextShadowNode.h>
#import <react/components/view/ViewComponentDescriptor.h>
#import <react/element/ComponentBuilder.h>
#import <react/element/Element.h>
#import <react/element/testUtils.h>
#import <react/textlayoutmanager/RCTTextLayoutManager.h>
#import <react/textlayoutmanager/TextLayoutManager.h>

@interface RCTParagraphComponentAccessibilityProviderTests : XCTestCase

@end

using namespace facebook::react;

//┌──    RootShadowNode    ─────────────────────────────┐
//│                                                     │
//│┌─── ParagraphShadowNodeA ─────────────────────────┐ │
//││ ┌─AA(AAA) ─────────┐ ┌─AB(ABA) ─┐ ┌─AC(ACA)────┐ │ │
//││ │ Please check out │ │ Facebook │ │    and     │ │ │
//││ └──────────────────┘ └──────────┘ └────────────┘ │ │
//││ ┌─AD(ADA) ──┐ ┌──AE(AEA) ──────────────────────┐ │ │
//││ │ Instagram │ │    for a full description.     │ │ │
//││ └───────────┘ └────────────────────────────────┘ │ │
//│└──────────────────────────────────────────────────┘ │
//│                                                     │
//│                                                     │
//│┌── ParagraphShadowNodeB ──────────────────────────┐ │
//││ ┌───BA(BAA) ───────────────────────────────────┐ │ │
//││ │   Lorem ipsum dolor sit amet, consectetur    │ │ │
//││ │ adipiscing elit. Maecenas ut risus et sapien │ │ │
//││ │   bibendum volutpat. Nulla facilisi. Cras    │ │ │
//││ │         imperdiet gravida tincidunt.         │ │ │
//││ └──────────────────────────────────────────────┘ │ │
//││ ┌─BB(BBA) ─────────────────────────────────────┐ │ │
//││ │  In tempor, tellus et vestibulum venenatis,  │ │ │
//││ │  lorem nunc eleifend lectus, a consectetur   │ │ │
//││ │             magna augue at arcu.             │ │ │
//││ └──────────────────────────────────────────────┘ │ │
//│└──────────────────────────────────────────────────┘ │
//│                                                     │
//│┌── ParagraphShadowNodeC ──────────────────────────┐ │
//││  ┌─CA(CAA) ────────┐                             │ │
//││  │   Lorem ipsum   │                             │ │
//││  └─────────────────┘                             │ │
//││ ┌─CB(CBA) ─────────────────────────────────────┐ │ │
//││ │ dolor sit amet, consectetur adipiscing elit. │ │ │
//││ │Maecenas ut risus et sapien bibendum volutpat.│ │ │
//││ │    Nulla facilisi. Cras imperdiet gravida    │ │ │
//││ │  tincidunt. In tempor, tellus et vestibulum  │ │ │
//││ │   venenatis, lorem nunc eleifend lectus, a   │ │ │
//││ │       consectetur magna augue at arcu.       │ │ │
//││ └──────────────────────────────────────────────┘ │ │
//││ ┌─CC(CCA) ────────┐                              │ │
//││ │    See Less     │                              │ │
//││ └─────────────────┘                              │ │
//│└──────────────────────────────────────────────────┘ │
//│                                                     │
//└─────────────────────────────────────────────────────┘

@implementation RCTParagraphComponentAccessibilityProviderTests {
  std::shared_ptr<ComponentBuilder> builder_;
  std::shared_ptr<RootShadowNode> rootShadowNode_;
  std::shared_ptr<ParagraphShadowNode> ParagrahShadowNodeA_;
  std::shared_ptr<ParagraphShadowNode> ParagrahShadowNodeB_;
  std::shared_ptr<ParagraphShadowNode> ParagrahShadowNodeC_;
  std::shared_ptr<TextShadowNode> TextShadowNodeAA_;
  std::shared_ptr<TextShadowNode> TextShadowNodeAB_;
  std::shared_ptr<TextShadowNode> TextShadowNodeAC_;
  std::shared_ptr<TextShadowNode> TextShadowNodeAD_;
  std::shared_ptr<TextShadowNode> TextShadowNodeAE_;
  std::shared_ptr<TextShadowNode> TextShadowNodeBA_;
  std::shared_ptr<TextShadowNode> TextShadowNodeBB_;
  std::shared_ptr<TextShadowNode> TextShadowNodeCA_;
  std::shared_ptr<TextShadowNode> TextShadowNodeCB_;
  std::shared_ptr<TextShadowNode> TextShadowNodeCC_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeAAA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeABA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeACA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeADA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeAEA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeBAA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeBBA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeCAA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeCBA_;
  std::shared_ptr<RawTextShadowNode> RawTextShadowNodeCCA_;
}

- (void)setUp
{
  [super setUp];
  builder_ = std::make_shared<ComponentBuilder>((simpleComponentBuilder()));
  auto element =
      Element<RootShadowNode>()
          .reference(rootShadowNode_)
          .tag(1)
          .props([] {
            auto sharedProps = std::make_shared<RootProps>();
            auto &props = *sharedProps;
            props.layoutConstraints = LayoutConstraints{{0, 0}, {500, 500}};
            auto &yogaStyle = props.yogaStyle;
            yogaStyle.dimensions()[YGDimensionWidth] = YGValue{200, YGUnitPoint};
            yogaStyle.dimensions()[YGDimensionHeight] = YGValue{200, YGUnitPoint};
            return sharedProps;
          })
          .children({
              Element<ParagraphShadowNode>()
                  .reference(ParagrahShadowNodeA_)
                  .props([] {
                    auto sharedProps = std::make_shared<ParagraphProps>();
                    auto &props = *sharedProps;
                    auto &yogaStyle = props.yogaStyle;
                    yogaStyle.positionType() = YGPositionTypeAbsolute;
                    yogaStyle.position()[YGEdgeLeft] = YGValue{0, YGUnitPoint};
                    yogaStyle.position()[YGEdgeTop] = YGValue{0, YGUnitPoint};
                    yogaStyle.dimensions()[YGDimensionWidth] = YGValue{200, YGUnitPoint};
                    yogaStyle.dimensions()[YGDimensionHeight] = YGValue{20, YGUnitPoint};
                    return sharedProps;
                  })
                  .children({
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeAA_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeAAA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = "Please check out ";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeAB_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            auto &props = *sharedProps;
                            props.textAttributes.accessibilityRole = AccessibilityRole::Link;
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeABA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = "facebook";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeAC_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeACA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = " and ";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeAD_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            auto &props = *sharedProps;
                            props.textAttributes.accessibilityRole = AccessibilityRole::Link;
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeADA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = "instagram";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeAE_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeAEA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = " for a full description.";
                            return sharedProps;
                          })}),
                  }),
              Element<ParagraphShadowNode>()
                  .reference(ParagrahShadowNodeB_)
                  .props([] {
                    auto sharedProps = std::make_shared<ParagraphProps>();
                    auto &props = *sharedProps;
                    auto &yogaStyle = props.yogaStyle;
                    yogaStyle.positionType() = YGPositionTypeAbsolute;
                    yogaStyle.position()[YGEdgeLeft] = YGValue{0, YGUnitPoint};
                    yogaStyle.position()[YGEdgeTop] = YGValue{30, YGUnitPoint};
                    yogaStyle.dimensions()[YGDimensionWidth] = YGValue{200, YGUnitPoint};
                    yogaStyle.dimensions()[YGDimensionHeight] = YGValue{50, YGUnitPoint};
                    return sharedProps;
                  })
                  .children({
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeBA_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            auto &props = *sharedProps;
                            props.textAttributes.accessibilityRole = AccessibilityRole::Link;
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeBAA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text =
                                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas ut risus et sapien bibendum volutpat. Nulla facilisi. Cras imperdiet gravida tincidunt. ";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeBB_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeBBA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text =
                                "In tempor, tellus et vestibulum venenatis, lorem nunc eleifend lectus, a consectetur magna augue at arcu.";
                            return sharedProps;
                          })}),
                  }),
              Element<ParagraphShadowNode>()
                  .reference(ParagrahShadowNodeC_)
                  .props([] {
                    auto sharedProps = std::make_shared<ParagraphProps>();
                    auto &props = *sharedProps;
                    auto &yogaStyle = props.yogaStyle;
                    yogaStyle.positionType() = YGPositionTypeAbsolute;
                    yogaStyle.position()[YGEdgeLeft] = YGValue{0, YGUnitPoint};
                    yogaStyle.position()[YGEdgeTop] = YGValue{90, YGUnitPoint};
                    yogaStyle.dimensions()[YGDimensionWidth] = YGValue{200, YGUnitPoint};
                    yogaStyle.dimensions()[YGDimensionHeight] = YGValue{50, YGUnitPoint};
                    return sharedProps;
                  })
                  .children({
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeCA_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            auto &props = *sharedProps;
                            props.textAttributes.accessibilityRole = AccessibilityRole::Link;
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeCAA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = "Lorem ipsum";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeCB_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeCBA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text =
                                " dolor sit amet, consectetur adipiscing elit. Maecenas ut risus et sapien bibendum volutpat. Nulla facilisi. Cras imperdiet gravida tincidunt. In tempor, tellus et vestibulum venenatis, lorem nunc eleifend lectus, a consectetur magna augue at arcu. ";
                            return sharedProps;
                          })}),
                      Element<TextShadowNode>()
                          .reference(TextShadowNodeCC_)
                          .props([] {
                            auto sharedProps = std::make_shared<TextProps>();
                            auto &props = *sharedProps;
                            props.textAttributes.accessibilityRole = AccessibilityRole::Button;
                            return sharedProps;
                          })
                          .children({Element<RawTextShadowNode>().reference(RawTextShadowNodeCCA_).props([] {
                            auto sharedProps = std::make_shared<RawTextProps>();
                            auto &props = *sharedProps;
                            props.text = "See Less";
                            return sharedProps;
                          })}),
                  }),
          });
  builder_->build(element);
  rootShadowNode_->layoutIfNeeded();
}

@end