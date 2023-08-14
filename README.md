# jdecomp.nvim
Neovim Plugin to decompile java classes. This plugin supports the following 3 providers:
1. [cfr](https://www.benf.org/other/cfr)
2. [procyon](https://github.com/mstrobel/procyon) 
3. [fernflower](https://github.com/fesh0r/fernflower)

The decompilers are not distributed by this plugin and must be downloaded seperately.

## Configuration
Lazy
``` lua
{
  'alienman5k/jdecomp.nvim',
  opts = {
    decompiler = 'procyon',
    provider = {
      cfr = {
        -- bin = 'cfr'
        jar = os.getenv('HOME') .. '/Software/cfr-0.152.jar'
      },
      procyon = {
        jar = os.getenv('HOME') .. '/Software/procyon-decompiler-0.6.0.jar'
      },
      fernflower = {
        jar = os.getenv('HOME') .. '/Software/fernflower.jar'
      }
    }
  }
}
```

## TODO List
- [ ] As part of the setup, provide an option to auto install decompilers
- [x] Implement code to support `fernflower` decompiler
- [ ] Add tests?
- [ ] Add user commands for files with other extensions?

