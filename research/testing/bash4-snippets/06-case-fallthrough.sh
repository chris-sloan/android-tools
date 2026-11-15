#!/bin/bash
# ;;& case fall-through (4.0)
case a in
  a) echo one ;;&
  *) echo two ;;
esac
