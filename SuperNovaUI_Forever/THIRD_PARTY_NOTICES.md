# Third-party notices

## VoidProf

`SuperNovaUI_Forever/Data/Recipes.lua` is derived from the WoW Forever recipe data of the addon **VoidProf**
(https://github.com/bughatti/voidprof, https://www.curseforge.com/wow/addons/voidprof): for each recipe, its spell id, its
English name and the skill needed to learn it. It is used by the Profession goal module to find a recipe's level from its name.
The file is made by `tools/gen-recipes.py` and is not edited by hand.

VoidProf is licensed under the MIT License:

```
MIT License

Copyright (c) 2026 Vede

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

VoidProf does not need to be installed: the data is inside this addon and the addon never reads VoidProf at run time.

## Skyborne Leyline & Convergence Marker

Not included in this addon. When installed, the Elemental Convergence markers module reads its list of convergences through
its public function `SLLCM_GetNodes` (tr0tsky, MIT, https://www.curseforge.com/wow/addons/sllcm).
