# Design System Strategy: The Monochromatic Editorial

This design system is a high-end, editorial-inspired framework specifically optimized for onboarding experiences. It rejects the "SaaS-standard" aesthetic of heavy borders and vibrant primary blues in favor of a sophisticated, tonal approach. By leveraging the clarity of OKLCH color spaces and a refined typographic hierarchy, it transforms a functional utility into a premium digital brand experience.

---

## 1. Creative North Star: The Digital Curator
The guiding philosophy of this system is **"The Digital Curator."** 

We aim for an experience that feels like a physical gallery or a high-end fashion lookbook. The interface should feel curated, not cluttered. We break the rigid template look through:
*   **Intentional Asymmetry:** Using the `24 (6rem)` spacing token for generous side-margins while keeping form elements tightly grouped.
*   **Tonal Depth:** Replacing harsh outlines with subtle background shifts (`surface` to `surface-container-low`).
*   **Type as Hero:** Using the `display-lg` scale to turn simple onboarding headers into bold, authoritative statements.

---

## 2. Color & Surface Architecture

The palette is rooted in a monochromatic OKLCH foundation, providing a "Paper and Ink" feel that ensures maximum readability and a timeless aesthetic.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders for sectioning or grouping. 
*   **How to define boundaries:** Use background color shifts. A `surface-container-low` section sitting on a `background` (oklch(1 0 0)) creates a sophisticated boundary that feels integrated, not "boxed in."
*   **Nesting Logic:** Treat the UI as stacked sheets of fine paper. 
    *   **Base:** `background`
    *   **Section:** `surface-container-low`
    *   **Interactive Card:** `surface-container-lowest` (White in Light mode)

### The "Glass & Gradient" Rule
To inject "soul" into the onboarding flow, use Glassmorphism for floating UI elements (like a "Help" fab or a "Progress" indicator). 
*   **Implementation:** Use `surface` at 70% opacity with a `backdrop-blur-md` effect.
*   **Signature Gradients:** For primary CTAs, apply a subtle linear gradient from `primary` (#5f5e5e) to `primary_dim` (#535252). This adds a tactile, "pressed-metal" quality.

---

## 3. Typography: Editorial Authority

We use two distinct families to create a high-contrast hierarchy: **Manrope** for structural authority and **Inter** for functional clarity.

| Level | Token | Font | Size | Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Manrope | 3.5rem | Onboarding "Welcome" screens. Tight letter-spacing. |
| **Headline** | `headline-sm` | Manrope | 1.5rem | Section headers within the form. |
| **Title** | `title-md` | Inter | 1.125rem | Form labels or card titles. |
| **Body** | `body-md` | Inter | 0.875rem | Explainer text and secondary info. |
| **Label** | `label-sm` | Inter | 0.6875rem | Micro-copy and Input hint text. |

**Stylistic Note:** All `display` and `headline` elements should use `font-weight: 600` and a `tracking-tighter` class to mimic high-end editorial layouts.

---

## 4. Elevation & Depth: Tonal Layering

Traditional drop shadows are replaced by **Ambient Occlusion** and **Tonal Stacking**.

*   **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` section. This creates a soft, natural "lift" without visual noise.
*   **Ambient Shadows:** If a card must float (e.g., a modal), use a diffused shadow: `shadow-[0px_20px_50px_rgba(45,52,53,0.06)]`. The shadow is a tinted version of the `on-surface` color, not a generic grey.
*   **The Ghost Border Fallback:** For accessibility on input fields, use the `outline-variant` token at **15% opacity**. Never use a 100% opaque border.

---

## 5. Signature Components

### Form Inputs & Select Menus
Onboarding relies on data entry. Our inputs must feel "integrated."
*   **Styling:** No borders. Use `surface-container-high` as the background fill.
*   **States:** On focus, the background shifts to `surface-container-highest` with a 1px "Ghost Border" using the `primary` token at 20% opacity.
*   **Select Menus:** Use the "Glassmorphism" rule. The dropdown menu should be semi-transparent with a heavy backdrop blur, allowing the form beneath it to peek through.

### Buttons
*   **Primary:** High-contrast `primary` (#5f5e5e) background with `on_primary` text. Use `rounded-md` (0.375rem) to maintain a modern, sharp edge.
*   **Secondary:** No fill. Use a `surface-container-high` background on hover.
*   **Tertiary:** Pure text with `label-md` styling, reserved for "Skip" or "Back" actions.

### Progress Navigation
Forboarding flows, avoid standard "stepper" dots. Use a **Thin Minimalist Bar** at the very top of the screen:
*   **Track:** `surface-container-highest` (Height: 2px)
*   **Indicator:** `primary` (#5f5e5e)

---

## 6. Do’s and Don’ts

### Do:
*   **DO** use whitespace as a separator. Use the `16 (4rem)` token between major form sections.
*   **DO** use `surface-container` tiers to create hierarchy.
*   **DO** lean into "Oversized" typography for empty states.

### Don't:
*   **DON'T** use `border-solid` or `border-1`. The "No-Line" rule is absolute.
*   **DON'T** use pure black (#000) for text. Use `on_surface` (oklch(0.145 0 0)) for a more natural, premium "ink" feel.
*   **DON'T** use standard Shadcn "Ring" offsets. Use subtle background transitions to indicate focus.

---

## 7. Accessibility Note
While we prioritize an editorial aesthetic, readability is paramount. Always ensure the contrast between `on_surface` and `surface-container` tiers maintains a minimum 4.5:1 ratio. The `outline-variant` "Ghost Border" should be increased to 40% opacity if the user has "Increase Contrast" settings enabled in their OS.